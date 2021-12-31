import { ComponentFixture, TestBed } from '@angular/core/testing';

import { StimmabgabeComponent } from './stimmabgabe.component';

describe('StimmabgabeComponent', () => {
  let component: StimmabgabeComponent;
  let fixture: ComponentFixture<StimmabgabeComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ StimmabgabeComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(StimmabgabeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
