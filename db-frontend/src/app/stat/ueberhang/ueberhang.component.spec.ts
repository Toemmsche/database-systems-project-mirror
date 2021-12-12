import { ComponentFixture, TestBed } from '@angular/core/testing';

import { UeberhangComponent } from './ueberhang.component';

describe('UeberhangComponent', () => {
  let component: UeberhangComponent;
  let fixture: ComponentFixture<UeberhangComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ UeberhangComponent ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(UeberhangComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
